using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class InventarioTipo
    {
        public int InventarioTipoId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(maximumLength: 50, ErrorMessage = "No puede ser mayor a {1} caracteres")]
        public string Nombre { get; set; }
    }
}
