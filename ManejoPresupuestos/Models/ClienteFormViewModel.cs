using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class ClienteFormViewModel
    {
        public int ClienteId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(150)]
        [Display(Name = "Nombre")]
        public string Nombre { get; set; } = string.Empty;

        [StringLength(30)]
        [Display(Name = "Teléfono")]
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
        public string? WhatsApp { get; set; }

        public bool EstaActivo { get; set; } = true; // por si quieres editar estado en UI
    }
}