using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class ClienteFormViewModel : IValidatableObject
    {
        public int ClienteId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(150)]
        [Display(Name = "Nombre(s)")]
        public string Nombre { get; set; } = string.Empty;

        [StringLength(80)]
        [Display(Name = "Apellido paterno")]
        public string? ApellidoPaterno { get; set; }

        [StringLength(80)]
        [Display(Name = "Apellido materno")]
        public string? ApellidoMaterno { get; set; }

        [StringLength(30)]
        [Display(Name = "Teléfono")]
        [RegularExpression(@"^\+?[0-9][0-9\s\-\(\)]{6,29}$", ErrorMessage = "Teléfono inválido. Usa solo números, espacios, (), - y opcional +.")]
        public string? Telefono { get; set; }

        [StringLength(120)]
        [EmailAddress(ErrorMessage = "Email inválido")]
        [Display(Name = "Email")]
        public string? Email { get; set; }

        [StringLength(250)]
        [Display(Name = "Dirección")]
        public string? Direccion { get; set; }

        [StringLength(80)]
        [Display(Name = "Instagram")]
        public string? Instagram { get; set; }

        [StringLength(30)]
        [Display(Name = "WhatsApp")]
        [RegularExpression(@"^\+?[0-9][0-9\s\-\(\)]{6,29}$", ErrorMessage = "WhatsApp inválido. Usa solo números, espacios, (), - y opcional +.")]
        public string? WhatsApp { get; set; }

        [Display(Name = "¿Es empresa?")]
        public bool EsEmpresa { get; set; } = false;

        [StringLength(13, MinimumLength = 12, ErrorMessage = "RFC inválido. Debe tener 12 o 13 caracteres.")]
        [RegularExpression(@"^(?i)([A-ZÑ&]{3,4})\d{6}([A-Z0-9]{3})$", ErrorMessage = "RFC inválido. Formato esperado: ABCD010101XXX")]
        [Display(Name = "RFC")]
        public string? RFC { get; set; }

        public bool EstaActivo { get; set; } = true;

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (EsEmpresa && string.IsNullOrWhiteSpace(RFC))
            {
                yield return new ValidationResult(
                    "RFC es obligatorio cuando el cliente es empresa.",
                    new[] { nameof(RFC) }
                );
            }
        }
    }
}